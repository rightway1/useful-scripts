// Docker registry
def registry = "hub.docker.com"

// list of available environments.  user references credentials held in jenkins secrets
def environments = [
	dev: ["dev-host-name:5432", "db-superuser-dev"],
	test: ["test-host-name:5432", "db-superuser-test"],
	live: ["live-host-name:5432", "db-superuser-live"]]

// List of choices for Databases to build.  Either mydb1 or mydb2.
def databases = [
	dbMyDb1:"customers",
	dbMyDb2:"management"
]

// Create choices string from map key values
def environmentChoices = new String()
for ( e in environments ) {
	environmentChoices = environmentChoices.concat("${e.key}\n")
}

def databaseChoices = new String()
for ( d in databases ) {
	databaseChoices = databaseChoices.concat("${d.key}\n")
}

pipeline {
	agent none
	parameters
	{
		choice(name: "ENVIRONMENT", choices: environmentChoices, description: "")
		choice(name: "DATABASES", choices: databaseChoices, description: "Whether to get info for the customer or management database")
	}

	options {
		// General Jenkins job properties
		buildDiscarder(logRotator(numToKeepStr:"5"))
		// Declarative-specific options
		skipDefaultCheckout()
		// "wrapper" steps that should wrap the entire build execution
		timeout(time: 5, unit: "MINUTES")
	}

	stages
	{
		stage("Run Flyway Info") {
			agent{ docker { label "loopback" image "hub.docker.com/flyway/flyway:latest" } }

			steps {
				checkout scm
				script {
					databaseFmt = databases.get(env.DATABASES)
					environmentFmt = environments.get(env.ENVIRONMENT)[0]
					credentialsIdStr = environments.get(env.ENVIRONMENT)[1]

					echo "Reporting migration status for ${databaseFmt} database in environment ${environmentFmt}"

					// Either get info for customer DB, or for management
					withCredentials([usernamePassword(credentialsId: "${credentialsIdStr}", usernameVariable: "pgUsername", passwordVariable: "pgPassword")]) {
						if ( databaseFmt == "management" ) {
							sh "flyway info -user=${pgUsername} -password=${pgPassword} -url=jdbc:postgresql://$environmentFmt/management  -schemas=_flyway -locations=filesystem:sql/management/ -jarDirs=/flywaycallbacks"
						} else {
							sh "flyway info -user=${pgUsername} -password=${pgPassword} -url=jdbc:postgresql://$environmentFmt/customers  -schemas=_flyway -locations=filesystem:sql/customers/ -jarDirs=/flywaycallbacks"

						}
					}
				}
				echo "Cleaning up"
				deleteDir()
			}
		}
	}
}

